using UrbanSync.Web.Models;

namespace UrbanSync.Web.Domain;

public class Evidencia
{
    public int Id { get; set; }

    public int IncidenciaId { get; set; }

    public Incidencia? Incidencia { get; set; }

    public string TipoEvidencia { get; set; } = "Foto";

    public string RutaArchivo { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public decimal? Latitud { get; set; }

    public decimal? Longitud { get; set; }

    public string UsuarioSubeId { get; set; } = string.Empty;

    public ApplicationUser? UsuarioSube { get; set; }

    public DateTime FechaSubida { get; set; } = DateTime.UtcNow;
}
