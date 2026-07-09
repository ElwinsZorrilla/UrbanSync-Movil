using System.ComponentModel.DataAnnotations;

namespace UrbanSync.Web.Dtos;

public class UbicacionInput
{
    public double Lat { get; set; }
    public double Lng { get; set; }

    [Required(ErrorMessage = "La dirección es obligatoria.")]
    public string Direccion { get; set; } = string.Empty;

    public string? Referencia { get; set; }

    public int? JurisdiccionId { get; set; }
}

public class CreateIncidentRequest
{
    [Required(ErrorMessage = "El tipo de incidencia es obligatorio.")]
    public int TipoIncidenciaId { get; set; }

    [Required(ErrorMessage = "La descripción es obligatoria.")]
    public string Descripcion { get; set; } = string.Empty;

    public string? Prioridad { get; set; }

    [Required(ErrorMessage = "La ubicación es obligatoria.")]
    public UbicacionInput Ubicacion { get; set; } = new();
}

public class TriageRequest
{
    public int? TipoIncidenciaId { get; set; }
    public string? Prioridad { get; set; }
    public string? Accion { get; set; }
    public int? JurisdiccionId { get; set; }
    public int? InstitucionAsignadaId { get; set; }
}

public class UpdateStatusRequest
{
    [Required(ErrorMessage = "El estado es obligatorio.")]
    public string Estado { get; set; } = string.Empty;
}

public class EvidenceDto
{
    public int Id { get; set; }
    public string TipoEvidencia { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public double? Latitud { get; set; }
    public double? Longitud { get; set; }
    public DateTime FechaSubida { get; set; }
    public string UsuarioSube { get; set; } = string.Empty;
}

public class IncidentDto
{
    public int Id { get; set; }
    public string CodigoCaso { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string Prioridad { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public int TipoIncidenciaId { get; set; }
    public string TipoIncidencia { get; set; } = string.Empty;
    public int? InstitucionAsignadaId { get; set; }
    public string? InstitucionAsignada { get; set; }
    public int JurisdiccionId { get; set; }
    public string Jurisdiccion { get; set; } = string.Empty;
    public string Direccion { get; set; } = string.Empty;
    public string? Referencia { get; set; }
    public double? Latitud { get; set; }
    public double? Longitud { get; set; }
    public string UsuarioReporta { get; set; } = string.Empty;
    public DateTime FechaReporte { get; set; }
    public DateTime? FechaAsignacion { get; set; }
    public DateTime? FechaCierre { get; set; }
    public List<EvidenceDto>? Evidencias { get; set; }
}
