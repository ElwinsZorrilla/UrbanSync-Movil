using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using UrbanSync.Web.Dtos;
using UrbanSync.Web.Models;
using UrbanSync.Web.Services;

namespace UrbanSync.Web.Controllers.Api;

[ApiController]
[Route("api/auth")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class AuthApiController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly JwtTokenService _jwt;
    private readonly ActivityLogger _activityLogger;

    public AuthApiController(
        UserManager<ApplicationUser> userManager,
        JwtTokenService jwt,
        ActivityLogger activityLogger)
    {
        _userManager = userManager;
        _jwt = jwt;
        _activityLogger = activityLogger;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<UserDto>> Register(ApiRegisterRequest request)
    {
        var existing = await _userManager.FindByEmailAsync(request.Email);

        if (existing != null)
            return Conflict(new ProblemDetails { Title = "Correo ya registrado", Detail = "Ya existe una cuenta con ese correo." });

        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            FullName = request.FullName,
            IdentificationNumber = request.IdentificationNumber,
            Position = "Ciudadano",
            IsActive = true,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, request.Password);

        if (!result.Succeeded)
        {
            foreach (var error in result.Errors)
                ModelState.AddModelError(string.Empty, error.Description);

            return ValidationProblem(ModelState);
        }

        await _userManager.AddToRoleAsync(user, "Ciudadano");

        return CreatedAtAction(nameof(Me), MapUser(user, "Ciudadano"));
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login(ApiLoginRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);

        if (user == null || !user.IsActive || !await _userManager.CheckPasswordAsync(user, request.Password))
            return Unauthorized(new ProblemDetails { Title = "Credenciales inválidas", Detail = "Usuario o contraseña incorrectos." });

        var roles = await _userManager.GetRolesAsync(user);
        var (token, expiresAt) = _jwt.CreateToken(user, roles);

        return Ok(new AuthResponse
        {
            Token = token,
            ExpiresAt = expiresAt,
            User = MapUser(user, roles.FirstOrDefault() ?? string.Empty)
        });
    }

    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(userId))
            return Unauthorized(new ProblemDetails { Title = "Usuario no identificado", Detail = "No fue posible identificar al usuario autenticado." });

        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
            return NotFound(new ProblemDetails { Title = "Usuario no encontrado", Detail = "La cuenta asociada a la sesión ya no existe." });

        var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);

        if (!result.Succeeded)
        {
            if (result.Errors.Any(e => e.Code == nameof(IdentityErrorDescriber.PasswordMismatch)))
                return Unauthorized(new ProblemDetails { Title = "Contraseña actual incorrecta", Detail = "La contraseña actual no es válida." });

            foreach (var error in result.Errors)
                ModelState.AddModelError(nameof(request.NewPassword), error.Description);

            return ValidationProblem(ModelState);
        }

        await _activityLogger.LogAsync(
            "Cambio de contraseña",
            $"El usuario {user.Email} cambió su contraseña.",
            "Usuarios");

        return NoContent();
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> Me()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
            return NotFound();

        var roles = await _userManager.GetRolesAsync(user);

        return Ok(MapUser(user, roles.FirstOrDefault() ?? string.Empty));
    }

    private static UserDto MapUser(ApplicationUser user, string role) => new()
    {
        Id = user.Id,
        Email = user.Email ?? string.Empty,
        FullName = user.FullName,
        IdentificationNumber = user.IdentificationNumber,
        Position = user.Position,
        Role = role
    };
}
