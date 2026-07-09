using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UrbanSync.Web.Data;
using UrbanSync.Web.Dtos;

namespace UrbanSync.Web.Controllers.Api;

[ApiController]
[Route("api/reports")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class ReportsApiController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public ReportsApiController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet("summary")]
    public async Task<ActionResult<ReportSummaryDto>> Summary()
    {
        var porEstado = await _db.Incidencias
            .GroupBy(i => i.Estado)
            .Select(g => new CountItem { Clave = g.Key, Total = g.Count() })
            .ToListAsync();

        var porPrioridad = await _db.Incidencias
            .GroupBy(i => i.Prioridad)
            .Select(g => new CountItem { Clave = g.Key, Total = g.Count() })
            .ToListAsync();

        var porTipo = await _db.Incidencias
            .GroupBy(i => i.TipoIncidencia!.Nombre)
            .Select(g => new CountItem { Clave = g.Key, Total = g.Count() })
            .ToListAsync();

        var porJurisdiccion = await _db.Incidencias
            .GroupBy(i => i.Ubicacion!.Jurisdiccion!.Nombre)
            .Select(g => new CountItem { Clave = g.Key, Total = g.Count() })
            .ToListAsync();

        return Ok(new ReportSummaryDto
        {
            Total = await _db.Incidencias.CountAsync(),
            PorEstado = porEstado,
            PorPrioridad = porPrioridad,
            PorTipo = porTipo,
            PorJurisdiccion = porJurisdiccion
        });
    }
}
