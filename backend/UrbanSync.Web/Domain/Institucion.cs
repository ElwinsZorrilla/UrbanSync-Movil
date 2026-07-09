namespace UrbanSync.Web.Domain;

public class Institucion
{
    public int Id { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string TipoInstitucion { get; set; } = string.Empty;

    public string? ContactoEmail { get; set; }

    public string? ContactoTelefono { get; set; }

    public bool Activo { get; set; } = true;
}
