namespace UrbanSync.Web.Domain;

public class Ubicacion
{
    public int Id { get; set; }

    public string Direccion { get; set; } = string.Empty;

    public string? Referencia { get; set; }

    public decimal? Latitud { get; set; }

    public decimal? Longitud { get; set; }

    public int JurisdiccionId { get; set; }

    public Jurisdiccion? Jurisdiccion { get; set; }

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
