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

    public AuthApiController(UserManager<ApplicationUser> userManager, JwtTokenService jwt)
    {
        _userManager = userManager;
        _jwt = jwt;
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
