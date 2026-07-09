using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UrbanSync.Web.Data;
using UrbanSync.Web.Domain;
using UrbanSync.Web.Dtos;
using UrbanSync.Web.Services;

namespace UrbanSync.Web.Controllers.Api;

[ApiController]
[Route("api/incidents")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class IncidentsApiController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly ActivityLogger _activityLogger;

    public IncidentsApiController(ApplicationDbContext db, ActivityLogger activityLogger)
    {
        _db = db;
        _activityLogger = activityLogger;
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;

    private bool IsStaff =>
        User.IsInRole("Administrador") || User.IsInRole("Supervisor") || User.IsInRole("Tecnico");

    [HttpPost]
    public async Task<ActionResult<IncidentDto>> Create(CreateIncidentRequest request)
    {
        var tipo = await _db.TiposIncidencia.FindAsync(request.TipoIncidenciaId);

        if (tipo == null)
        {
            ModelState.AddModelError(nameof(request.TipoIncidenciaId), "El tipo de incidencia no existe.");
            return ValidationProblem(ModelState);
        }

        var jurisdiccionId = await ResolveJurisdiccionIdAsync(request.Ubicacion.JurisdiccionId);

        if (jurisdiccionId == null)
            return Problem("No hay una jurisdicción configurada en el sistema.", statusCode: StatusCodes.Status409Conflict);

        var incidencia = new Incidencia
        {
            CodigoCaso = GenerarCodigo(),
            UsuarioReportaId = CurrentUserId,
            TipoIncidenciaId = tipo.Id,
            Ubicacion = new Ubicacion
            {
                Direccion = request.Ubicacion.Direccion,
                Referencia = request.Ubicacion.Referencia,
                Latitud = (decimal)request.Ubicacion.Lat,
                Longitud = (decimal)request.Ubicacion.Lng,
                JurisdiccionId = jurisdiccionId.Value
            },
            InstitucionAsignadaId = tipo.InstitucionId,
            Estado = "Registrada",
            Prioridad = string.IsNullOrWhiteSpace(request.Prioridad) ? "Media" : request.Prioridad!,
            Descripcion = request.Descripcion,
            FechaReporte = DateTime.UtcNow
        };

        _db.Incidencias.Add(incidencia);
        await _db.SaveChangesAsync();

        await _activityLogger.LogAsync("Reporte de incidencia", $"Incidencia {incidencia.CodigoCaso} registrada.");

        var dto = await LoadDtoAsync(incidencia.Id, includeEvidencias: false);
        return CreatedAtAction(nameof(GetById), new { id = incidencia.Id }, dto);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<IncidentDto>>> List(
        [FromQuery] string? status,
        [FromQuery] int? type,
        [FromQuery] string? priority,
        [FromQuery] int? jurisdictionId,
        [FromQuery] bool? mine)
    {
        var query = BaseQuery();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(i => i.Estado == status);

        if (type.HasValue)
            query = query.Where(i => i.TipoIncidenciaId == type.Value);

        if (!string.IsNullOrWhiteSpace(priority))
            query = query.Where(i => i.Prioridad == priority);

        if (jurisdictionId.HasValue)
            query = query.Where(i => i.Ubicacion!.JurisdiccionId == jurisdictionId.Value);

        if (!IsStaff)
        {
            var uid = CurrentUserId;
            query = query.Where(i => i.UsuarioReportaId == uid);
        }
        else if (mine == true)
        {
            var uid = CurrentUserId;
            query = query.Where(i => i.UsuarioReportaId == uid);
        }

        var incidencias = await query.OrderByDescending(i => i.FechaReporte).ToListAsync();

        return Ok(incidencias.Select(i => ApiMappers.MapIncident(i, Request, includeEvidencias: false)));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<IncidentDto>> GetById(int id)
    {
        var incidencia = await BaseQuery()
            .Include(i => i.Evidencias)
                .ThenInclude(e => e.UsuarioSube)
            .FirstOrDefaultAsync(i => i.Id == id);

        if (incidencia == null)
            return NotFound();

        if (!IsStaff && incidencia.UsuarioReportaId != CurrentUserId)
            return StatusCode(StatusCodes.Status403Forbidden);

        return Ok(ApiMappers.MapIncident(incidencia, Request, includeEvidencias: true));
    }

    [HttpPatch("{id:int}/triage")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Administrador,Supervisor")]
    public async Task<ActionResult<IncidentDto>> Triage(int id, TriageRequest request)
    {
        var incidencia = await _db.Incidencias
            .Include(i => i.Ubicacion)
            .FirstOrDefaultAsync(i => i.Id == id);

        if (incidencia == null)
            return NotFound();

        if (request.TipoIncidenciaId.HasValue)
        {
            var tipo = await _db.TiposIncidencia.FindAsync(request.TipoIncidenciaId.Value);

            if (tipo == null)
            {
                ModelState.AddModelError(nameof(request.TipoIncidenciaId), "El tipo de incidencia no existe.");
                return ValidationProblem(ModelState);
            }

            incidencia.TipoIncidenciaId = tipo.Id;

            if (!request.InstitucionAsignadaId.HasValue)
                incidencia.InstitucionAsignadaId = tipo.InstitucionId;
        }

        if (request.InstitucionAsignadaId.HasValue)
            incidencia.InstitucionAsignadaId = request.InstitucionAsignadaId.Value;

        if (!string.IsNullOrWhiteSpace(request.Prioridad))
            incidencia.Prioridad = request.Prioridad!;

        if (request.JurisdiccionId.HasValue && incidencia.Ubicacion != null)
            incidencia.Ubicacion.JurisdiccionId = request.JurisdiccionId.Value;

        incidencia.Estado = AccionToEstado(request.Accion);

        if (incidencia.Estado == "Asignada")
            incidencia.FechaAsignacion = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await _activityLogger.LogAsync("Triage", $"Incidencia {incidencia.CodigoCaso} analizada ({incidencia.Estado}).");

        return Ok(await LoadDtoAsync(incidencia.Id, includeEvidencias: false));
    }

    [HttpPatch("{id:int}/status")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Administrador,Supervisor,Tecnico")]
    public async Task<ActionResult<IncidentDto>> UpdateStatus(int id, UpdateStatusRequest request)
    {
        var incidencia = await _db.Incidencias.FirstOrDefaultAsync(i => i.Id == id);

        if (incidencia == null)
            return NotFound();

        var estadosValidos = new[] { "Registrada", "EnAnalisis", "Asignada", "EnProceso", "Cerrada", "Rechazada" };
        if (!estadosValidos.Contains(request.Estado))
        {
            ModelState.AddModelError(nameof(request.Estado), "Estado inválido.");
            return ValidationProblem(ModelState);
        }

        incidencia.Estado = request.Estado;

        if (request.Estado == "Cerrada")
            incidencia.FechaCierre = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await _activityLogger.LogAsync("Cambio de estado", $"Incidencia {incidencia.CodigoCaso} → {incidencia.Estado}.");

        return Ok(await LoadDtoAsync(incidencia.Id, includeEvidencias: false));
    }

    private IQueryable<Incidencia> BaseQuery() => _db.Incidencias
        .Include(i => i.TipoIncidencia)
        .Include(i => i.InstitucionAsignada)
        .Include(i => i.UsuarioReporta)
        .Include(i => i.Ubicacion)
            .ThenInclude(u => u!.Jurisdiccion);

    private async Task<IncidentDto> LoadDtoAsync(int id, bool includeEvidencias)
    {
        var query = BaseQuery();

        if (includeEvidencias)
            query = query.Include(i => i.Evidencias).ThenInclude(e => e.UsuarioSube);

        var incidencia = await query.FirstAsync(i => i.Id == id);
        return ApiMappers.MapIncident(incidencia, Request, includeEvidencias);
    }

    private async Task<int?> ResolveJurisdiccionIdAsync(int? provided)
    {
        if (provided.HasValue && await _db.Jurisdicciones.AnyAsync(j => j.Id == provided.Value))
            return provided.Value;

        var root = await _db.Jurisdicciones
            .Where(j => j.Activo)
            .OrderBy(j => j.JurisdiccionPadreId == null ? 0 : 1)
            .ThenBy(j => j.Id)
            .FirstOrDefaultAsync();

        return root?.Id;
    }

    private static string AccionToEstado(string? accion) => (accion ?? string.Empty).ToLowerInvariant() switch
    {
        "asignar" => "Asignada",
        "derivar" => "Asignada",
        "rechazar" => "Rechazada",
        _ => "EnAnalisis"
    };

    private static string GenerarCodigo() =>
        $"INC-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..8].ToUpperInvariant()}";
}
