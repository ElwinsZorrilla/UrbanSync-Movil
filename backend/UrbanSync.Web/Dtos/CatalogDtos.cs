namespace UrbanSync.Web.Dtos;

public class JurisdictionDto
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Nivel { get; set; } = string.Empty;
    public int? JurisdiccionPadreId { get; set; }
}

public class InstitutionDto
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string TipoInstitucion { get; set; } = string.Empty;
    public string? ContactoEmail { get; set; }
    public string? ContactoTelefono { get; set; }
}

public class IncidentTypeDto
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public int InstitucionId { get; set; }
    public string InstitucionNombre { get; set; } = string.Empty;
}
