using System.ComponentModel.DataAnnotations;

namespace UrbanSync.Web.Dtos;

public class CreateWorkOrderRequest
{
    [Required(ErrorMessage = "La incidencia es obligatoria.")]
    public int IncidenciaId { get; set; }

    [Required(ErrorMessage = "El técnico asignado es obligatorio.")]
    public string UsuarioAsignadoId { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descripción del trabajo es obligatoria.")]
    public string DescripcionTrabajo { get; set; } = string.Empty;
}

public class CompleteWorkOrderRequest
{
    [Required(ErrorMessage = "El resultado es obligatorio.")]
    public string Resultado { get; set; } = string.Empty;

    public string? DescripcionTrabajo { get; set; }
}

public class WorkOrderDto
{
    public int Id { get; set; }
    public int IncidenciaId { get; set; }
    public string CodigoCaso { get; set; } = string.Empty;
    public string UsuarioAsignadoId { get; set; } = string.Empty;
    public string UsuarioAsignado { get; set; } = string.Empty;
    public string DescripcionTrabajo { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public DateTime? FechaInicio { get; set; }
    public DateTime? FechaFin { get; set; }
    public string? Resultado { get; set; }
}
