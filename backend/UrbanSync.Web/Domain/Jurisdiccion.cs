namespace UrbanSync.Web.Domain;

public class Jurisdiccion
{
    public int Id { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string Nivel { get; set; } = string.Empty;

    public int? JurisdiccionPadreId { get; set; }

    public Jurisdiccion? JurisdiccionPadre { get; set; }

    public bool Activo { get; set; } = true;
}
