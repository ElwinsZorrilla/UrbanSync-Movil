using UrbanSync.Web.Models;

namespace UrbanSync.Web.Domain;

public class Trabajo
{
    public int Id { get; set; }

    public int IncidenciaId { get; set; }

    public Incidencia? Incidencia { get; set; }

    public string UsuarioAsignadoId { get; set; } = string.Empty;

    public ApplicationUser? UsuarioAsignado { get; set; }

    public string DescripcionTrabajo { get; set; } = string.Empty;

    public string Estado { get; set; } = "Pendiente";

    public DateTime? FechaInicio { get; set; }

    public DateTime? FechaFin { get; set; }

    public string? Resultado { get; set; }
}
