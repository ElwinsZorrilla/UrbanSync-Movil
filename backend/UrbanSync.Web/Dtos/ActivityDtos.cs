using System.ComponentModel.DataAnnotations;

namespace UrbanSync.Web.Dtos;

public class CreateActivityRequest
{
    [Required(ErrorMessage = "La acción es obligatoria.")]
    [StringLength(50, ErrorMessage = "La acción no puede superar 50 caracteres.")]
    public string Accion { get; set; } = string.Empty;

    [StringLength(80, ErrorMessage = "La entidad no puede superar 80 caracteres.")]
    public string? Entidad { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "El identificador de la entidad debe ser mayor que cero.")]
    public int? EntidadId { get; set; }

    [StringLength(400, ErrorMessage = "El detalle no puede superar 400 caracteres.")]
    public string? Detalle { get; set; }
}

public class ActivityDto
{
    public int Id { get; set; }
    public string? UsuarioId { get; set; }
    public string? NombreUsuario { get; set; }
    public string Accion { get; set; } = string.Empty;
    public string? Entidad { get; set; }
    public int? EntidadId { get; set; }
    public string? Detalle { get; set; }
    public string? IpOrigen { get; set; }
    public DateTime FechaHora { get; set; }
}
