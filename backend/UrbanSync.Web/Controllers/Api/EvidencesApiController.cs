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
[Route("api/incidents/{incidentId:int}/evidences")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class EvidencesApiController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly IWebHostEnvironment _env;
    private readonly ActivityLogger _activityLogger;

    public EvidencesApiController(ApplicationDbContext db, IWebHostEnvironment env, ActivityLogger activityLogger)
    {
        _db = db;
        _env = env;
        _activityLogger = activityLogger;
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<EvidenceDto>>> List(int incidentId)
    {
        if (!await _db.Incidencias.AnyAsync(i => i.Id == incidentId))
            return NotFound();

        var evidencias = await _db.Evidencias
            .Include(e => e.UsuarioSube)
            .Where(e => e.IncidenciaId == incidentId)
            .OrderByDescending(e => e.FechaSubida)
            .ToListAsync();

        return Ok(evidencias.Select(e => ApiMappers.MapEvidence(e, Request)));
    }

    [HttpPost]
    [RequestSizeLimit(52_428_800)]
    public async Task<ActionResult<EvidenceDto>> Upload(
        int incidentId,
        IFormFile file,
        [FromForm] string? tipo,
        [FromForm] double? lat,
        [FromForm] double? lng,
        [FromForm] string? descripcion)
    {
        var incidencia = await _db.Incidencias.FirstOrDefaultAsync(i => i.Id == incidentId);
        if (incidencia == null)
            return NotFound();

        var esStaff = User.IsInRole("Administrador") || User.IsInRole("Supervisor") || User.IsInRole("Tecnico");
        if (!esStaff && incidencia.UsuarioReportaId != CurrentUserId)
            return StatusCode(StatusCodes.Status403Forbidden);

        if (file == null || file.Length == 0)
            return BadRequest(new ProblemDetails { Title = "Archivo requerido", Detail = "Debe adjuntar un archivo de evidencia." });

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var permitidas = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif", ".mp4", ".pdf" };
        if (!permitidas.Contains(extension))
            return BadRequest(new ProblemDetails { Title = "Tipo de archivo no permitido", Detail = "Formatos válidos: imágenes, mp4 o pdf." });

        var webRoot = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var uploadsDir = Path.Combine(webRoot, "uploads");
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(uploadsDir, fileName);

        await using (var stream = System.IO.File.Create(fullPath))
        {
            await file.CopyToAsync(stream);
        }

        var evidencia = new Evidencia
        {
            IncidenciaId = incidentId,
            TipoEvidencia = string.IsNullOrWhiteSpace(tipo) ? "Foto" : tipo!,
            RutaArchivo = $"/uploads/{fileName}",
            Descripcion = descripcion,
            Latitud = lat.HasValue ? (decimal)lat.Value : null,
            Longitud = lng.HasValue ? (decimal)lng.Value : null,
            UsuarioSubeId = CurrentUserId,
            FechaSubida = DateTime.UtcNow
        };

        _db.Evidencias.Add(evidencia);
        await _db.SaveChangesAsync();
        await _activityLogger.LogAsync("Evidencia", $"Evidencia subida a incidencia #{incidentId}.");

        var guardada = await _db.Evidencias
            .Include(e => e.UsuarioSube)
            .FirstAsync(e => e.Id == evidencia.Id);

        return CreatedAtAction(nameof(List), new { incidentId }, ApiMappers.MapEvidence(guardada, Request));
    }
}
