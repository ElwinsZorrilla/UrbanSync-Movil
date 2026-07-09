using System.ComponentModel.DataAnnotations;

namespace UrbanSync.Web.ViewModels;

public class UserCreateViewModel
{
    [Required(ErrorMessage = "El nombre completo es obligatorio.")]
    [Display(Name = "Nombre completo")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "La cédula es obligatoria.")]
    [Display(Name = "Cédula")]
    public string IdentificationNumber { get; set; } = string.Empty;

    [Required(ErrorMessage = "El cargo es obligatorio.")]
    [Display(Name = "Cargo")]
    public string Position { get; set; } = string.Empty;

    [Required(ErrorMessage = "El correo es obligatorio.")]
    [EmailAddress(ErrorMessage = "Correo inválido.")]
    [Display(Name = "Correo")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "El rol es obligatorio.")]
    [Display(Name = "Rol")]
    public string Role { get; set; } = string.Empty;

    [Required(ErrorMessage = "La contraseña es obligatoria.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña temporal")]
    public string Password { get; set; } = string.Empty;
}