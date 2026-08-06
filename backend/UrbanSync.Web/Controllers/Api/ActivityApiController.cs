using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UrbanSync.Web.Data;
using UrbanSync.Web.Dtos;
using UrbanSync.Web.Services;

namespace UrbanSync.Web.Controllers.Api;

[ApiController]
[Route("api/activity")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class ActivityApiController : ControllerBase
{
    private const string RolesLectura = "Administrador,Supervisor";

    private readonly ApplicationDbContext _db;
    private readonly ActivityLogger _activityLogger;

    public ActivityApiController(ApplicationDbContext db, ActivityLogger activityLogger)
    {
        _db = db;
        _activityLogger = activityLogger;
    }

    [HttpGet]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = RolesLectura)]
    public async Task<ActionResult<IEnumerable<ActivityDto>>> List(
        [FromQuery] string? usuarioId,
        [FromQuery] string? entidad,
        [FromQuery] string? accion,
        [FromQuery] DateTime? fechaInicio,
        [FromQuery] DateTime? fechaFin)
    {
        if (fechaInicio.HasValue && fechaFin.HasValue && fechaInicio > fechaFin)
        {
            ModelState.AddModelError(nameof(fechaInicio), "La fecha inicial no puede ser posterior a la fecha final.");
            return ValidationProblem(ModelState);
        }

        var query = _db.UserActivities.Include(a => a.User).AsQueryable();

        if (!string.IsNullOrWhiteSpace(usuarioId))
            query = query.Where(a => a.UserId == usuarioId);

        if (!string.IsNullOrWhiteSpace(entidad))
            query = query.Where(a => a.Entity == entidad);

        if (!string.IsNullOrWhiteSpace(accion))
            query = query.Where(a => a.Action == accion);

        if (fechaInicio.HasValue)
        {
            var desde = ToUtc(fechaInicio.Value);
            query = query.Where(a => a.CreatedAt >= desde);
        }

        if (fechaFin.HasValue)
        {
            var hasta = ToUtc(fechaFin.Value);
            query = query.Where(a => a.CreatedAt <= hasta);
        }

        var activities = await query.OrderByDescending(a => a.CreatedAt).ToListAsync();

        return Ok(activities.Select(MapActivity));
    }

    [HttpGet("{id:int}")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Roles = RolesLectura)]
    public async Task<ActionResult<ActivityDto>> GetById(int id)
    {
        var activity = await _db.UserActivities
            .Include(a => a.User)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (activity == null)
            return NotFound(new ProblemDetails
            {
                Title = "Recurso no encontrado",
                Detail = $"No se encontró ningún registro de auditoría con el ID {id}."
            });

        return Ok(MapActivity(activity));
    }

    [HttpPost]
    public async Task<ActionResult<ActivityDto>> Create(CreateActivityRequest request)
    {
        var activity = await _activityLogger.LogAsync(
            request.Accion.Trim(),
            request.Detalle?.Trim() ?? string.Empty,
            Normalizar(request.Entidad),
            request.EntidadId);

        if (activity == null)
            return Unauthorized(new ProblemDetails
            {
                Title = "Usuario no identificado",
                Detail = "No fue posible identificar al usuario autenticado."
            });

        var guardada = await _db.UserActivities
            .Include(a => a.User)
            .FirstAsync(a => a.Id == activity.Id);

        return CreatedAtAction(nameof(GetById), new { id = guardada.Id }, MapActivity(guardada));
    }

    private static ActivityDto MapActivity(Models.UserActivity a) => new()
    {
        Id = a.Id,
        UsuarioId = a.UserId,
        NombreUsuario = a.User?.FullName,
        Accion = a.Action,
        Entidad = a.Entity,
        EntidadId = a.EntityId,
        Detalle = a.Description,
        IpOrigen = a.IpAddress,
        FechaHora = a.CreatedAt
    };

    private static string? Normalizar(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static DateTime ToUtc(DateTime value) => value.Kind switch
    {
        DateTimeKind.Utc => value,
        DateTimeKind.Local => value.ToUniversalTime(),
        _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
    };
}
