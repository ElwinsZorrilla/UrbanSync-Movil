using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UrbanSync.Web.Data;
using UrbanSync.Web.Dtos;

namespace UrbanSync.Web.Controllers.Api;

[ApiController]
[Route("api")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class CatalogsApiController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public CatalogsApiController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet("jurisdictions")]
    public async Task<ActionResult<IEnumerable<JurisdictionDto>>> Jurisdictions()
    {
        var items = await _db.Jurisdicciones
            .Where(j => j.Activo)
            .OrderBy(j => j.Nombre)
            .Select(j => new JurisdictionDto
            {
                Id = j.Id,
                Nombre = j.Nombre,
                Nivel = j.Nivel,
                JurisdiccionPadreId = j.JurisdiccionPadreId
            })
            .ToListAsync();

        return Ok(items);
    }

    [HttpGet("jurisdictions/resolve")]
    public async Task<ActionResult<JurisdictionDto>> Resolve([FromQuery] double lat, [FromQuery] double lng)
    {
        var root = await _db.Jurisdicciones
            .Where(j => j.Activo)
            .OrderBy(j => j.JurisdiccionPadreId == null ? 0 : 1)
            .ThenBy(j => j.Id)
            .Select(j => new JurisdictionDto
            {
                Id = j.Id,
                Nombre = j.Nombre,
                Nivel = j.Nivel,
                JurisdiccionPadreId = j.JurisdiccionPadreId
            })
            .FirstOrDefaultAsync();

        if (root == null)
            return NotFound(new ProblemDetails { Title = "Sin jurisdicciones", Detail = "No hay jurisdicciones configuradas." });

        return Ok(root);
    }

    [HttpGet("institutions")]
    public async Task<ActionResult<IEnumerable<InstitutionDto>>> Institutions([FromQuery] int? incidentTypeId)
    {
        var query = _db.Instituciones.Where(i => i.Activo);

        if (incidentTypeId.HasValue)
        {
            var institucionId = await _db.TiposIncidencia
                .Where(t => t.Id == incidentTypeId.Value)
                .Select(t => t.InstitucionId)
                .FirstOrDefaultAsync();

            query = query.Where(i => i.Id == institucionId);
        }

        var items = await query
            .OrderBy(i => i.Nombre)
            .Select(i => new InstitutionDto
            {
                Id = i.Id,
                Nombre = i.Nombre,
                TipoInstitucion = i.TipoInstitucion,
                ContactoEmail = i.ContactoEmail,
                ContactoTelefono = i.ContactoTelefono
            })
            .ToListAsync();

        return Ok(items);
    }

    [HttpGet("incident-types")]
    public async Task<ActionResult<IEnumerable<IncidentTypeDto>>> IncidentTypes()
    {
        var items = await _db.TiposIncidencia
            .Include(t => t.Institucion)
            .Where(t => t.Activo)
            .OrderBy(t => t.Nombre)
            .Select(t => new IncidentTypeDto
            {
                Id = t.Id,
                Nombre = t.Nombre,
                Descripcion = t.Descripcion,
                InstitucionId = t.InstitucionId,
                InstitucionNombre = t.Institucion!.Nombre
            })
            .ToListAsync();

        return Ok(items);
    }
}
