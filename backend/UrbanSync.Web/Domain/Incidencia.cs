using UrbanSync.Web.Models;

namespace UrbanSync.Web.Domain;

public class Incidencia
{
    public int Id { get; set; }

    public string CodigoCaso { get; set; } = string.Empty;

    public string UsuarioReportaId { get; set; } = string.Empty;

    public ApplicationUser? UsuarioReporta { get; set; }

    public int TipoIncidenciaId { get; set; }

    public TipoIncidencia? TipoIncidencia { get; set; }

    public int UbicacionId { get; set; }

    public Ubicacion? Ubicacion { get; set; }

    public int? InstitucionAsignadaId { get; set; }

    public Institucion? InstitucionAsignada { get; set; }

    public string Estado { get; set; } = "Registrada";

    public string Prioridad { get; set; } = "Media";

    public string Descripcion { get; set; } = string.Empty;

    public DateTime FechaReporte { get; set; } = DateTime.UtcNow;

    public DateTime? FechaAsignacion { get; set; }

    public DateTime? FechaCierre { get; set; }

    public ICollection<Evidencia> Evidencias { get; set; } = new List<Evidencia>();

    public ICollection<Trabajo> Trabajos { get; set; } = new List<Trabajo>();
}
