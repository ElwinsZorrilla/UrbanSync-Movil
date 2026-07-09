namespace UrbanSync.Web.Domain;

public class TipoIncidencia
{
    public int Id { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public int InstitucionId { get; set; }

    public Institucion? Institucion { get; set; }

    public bool Activo { get; set; } = true;
}
