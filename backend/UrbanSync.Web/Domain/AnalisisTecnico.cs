using UrbanSync.Web.Models;

namespace UrbanSync.Web.Domain;

public class AnalisisTecnico
{
    public int Id { get; set; }

    public int IncidenciaId { get; set; }

    public Incidencia? Incidencia { get; set; }

    public string UsuarioTecnicoId { get; set; } = string.Empty;

    public ApplicationUser? UsuarioTecnico { get; set; }

    public string Diagnostico { get; set; } = string.Empty;

    public string? AccionesRecomendadas { get; set; }

    public DateTime FechaAnalisis { get; set; } = DateTime.UtcNow;
}
