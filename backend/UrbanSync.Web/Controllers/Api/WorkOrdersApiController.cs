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
[Route("api/work-orders")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class WorkOrdersApiController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly ActivityLogger _activityLogger;

    public WorkOrdersApiController(ApplicationDbContext db, ActivityLogger activityLogger)
    {
        _db = db;
        _activityLogger = activityLogger;
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;

    private bool EsGestor => User.IsInRole("Administrador") || User.IsInRole("Supervisor");

    [HttpGet]
    public async Task<ActionResult<IEnumerable<WorkOrderDto>>> List(
        [FromQuery] string? technicianId,
        [FromQuery] string? status,
        [FromQuery] int? incidentId)
    {
        var query = _db.Trabajos
            .Include(t => t.Incidencia)
            .Include(t => t.UsuarioAsignado)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(technicianId))
            query = query.Where(t => t.UsuarioAsignadoId == technicianId);

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(t => t.Estado == status);

        if (incidentId.HasValue)
            query = query.Where(t => t.IncidenciaId == incidentId.Value);

        var items = await query.OrderByDescending(t => t.Id).ToListAsync();
        return Ok(items.Select(ApiMappers.MapWorkOrder));
    }

    [HttpPost]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Administrador,Supervisor")]
    public async Task<ActionResult<WorkOrderDto>> Create(CreateWorkOrderRequest request)
    {
        var incidencia = await _db.Incidencias.FirstOrDefaultAsync(i => i.Id == request.IncidenciaId);

        if (incidencia == null)
        {
            ModelState.AddModelError(nameof(request.IncidenciaId), "La incidencia no existe.");
            return ValidationProblem(ModelState);
        }

        var trabajo = new Trabajo
        {
            IncidenciaId = request.IncidenciaId,
            UsuarioAsignadoId = request.UsuarioAsignadoId,
            DescripcionTrabajo = request.DescripcionTrabajo,
            Estado = "Pendiente"
        };

        _db.Trabajos.Add(trabajo);

        incidencia.Estado = "Asignada";
        incidencia.FechaAsignacion = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        await _activityLogger.LogAsync("Orden de trabajo", $"Trabajo creado para incidencia {incidencia.CodigoCaso}.");

        return CreatedAtAction(nameof(GetById), new { id = trabajo.Id }, await LoadDtoAsync(trabajo.Id));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<WorkOrderDto>> GetById(int id)
    {
        var trabajo = await _db.Trabajos
            .Include(t => t.Incidencia)
            .Include(t => t.UsuarioAsignado)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (trabajo == null)
            return NotFound();

        return Ok(ApiMappers.MapWorkOrder(trabajo));
    }

    [HttpPatch("{id:int}/start")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Tecnico,Administrador,Supervisor")]
    public async Task<ActionResult<WorkOrderDto>> Start(int id)
    {
        var trabajo = await _db.Trabajos.Include(t => t.Incidencia).FirstOrDefaultAsync(t => t.Id == id);

        if (trabajo == null)
            return NotFound();

        if (!EsGestor && trabajo.UsuarioAsignadoId != CurrentUserId)
            return StatusCode(StatusCodes.Status403Forbidden);

        trabajo.Estado = "EnProgreso";
        trabajo.FechaInicio = DateTime.UtcNow;

        if (trabajo.Incidencia != null)
            trabajo.Incidencia.Estado = "EnProceso";

        await _db.SaveChangesAsync();
        await _activityLogger.LogAsync("Orden de trabajo", $"Trabajo #{trabajo.Id} iniciado.");

        return Ok(await LoadDtoAsync(trabajo.Id));
    }

    [HttpPatch("{id:int}/complete")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = "Tecnico,Administrador,Supervisor")]
    public async Task<ActionResult<WorkOrderDto>> Complete(int id, CompleteWorkOrderRequest request)
    {
        var trabajo = await _db.Trabajos.Include(t => t.Incidencia).FirstOrDefaultAsync(t => t.Id == id);

        if (trabajo == null)
            return NotFound();

        if (!EsGestor && trabajo.UsuarioAsignadoId != CurrentUserId)
            return StatusCode(StatusCodes.Status403Forbidden);

        trabajo.Estado = "Finalizado";
        trabajo.FechaFin = DateTime.UtcNow;
        trabajo.Resultado = request.Resultado;

        if (!string.IsNullOrWhiteSpace(request.DescripcionTrabajo))
            trabajo.DescripcionTrabajo = request.DescripcionTrabajo!;

        if (trabajo.Incidencia != null)
        {
            trabajo.Incidencia.Estado = "Cerrada";
            trabajo.Incidencia.FechaCierre = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync();
        await _activityLogger.LogAsync("Orden de trabajo", $"Trabajo #{trabajo.Id} finalizado.");

        return Ok(await LoadDtoAsync(trabajo.Id));
    }

    private async Task<WorkOrderDto> LoadDtoAsync(int id)
    {
        var trabajo = await _db.Trabajos
            .Include(t => t.Incidencia)
            .Include(t => t.UsuarioAsignado)
            .FirstAsync(t => t.Id == id);

        return ApiMappers.MapWorkOrder(trabajo);
    }
}
