using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using UrbanSync.Web.Models;
using UrbanSync.Web.Services;
using UrbanSync.Web.ViewModels;

namespace UrbanSync.Web.Controllers;

[Authorize(Roles = "Administrador")]
public class UserManagementController : Controller
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ActivityLogger _activityLogger;

    public UserManagementController(
        UserManager<ApplicationUser> userManager,
        ActivityLogger activityLogger)
    {
        _userManager = userManager;
        _activityLogger = activityLogger;
    }

    public async Task<IActionResult> Index()
    {
        var users = _userManager.Users.ToList();
        var result = new List<UserListViewModel>();

        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);

            result.Add(new UserListViewModel
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email ?? "",
                Position = user.Position,
                IsActive = user.IsActive,
                Role = roles.FirstOrDefault() ?? "Sin rol"
            });
        }

        return View(result);
    }

    [HttpGet]
    public IActionResult Create()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Create(UserCreateViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        var user = new ApplicationUser
        {
            UserName = model.Email,
            Email = model.Email,
            FullName = model.FullName,
            IdentificationNumber = model.IdentificationNumber,
            Position = model.Position,
            IsActive = true,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, model.Password);

        if (!result.Succeeded)
        {
            foreach (var error in result.Errors)
                ModelState.AddModelError("", error.Description);

            return View(model);
        }

        await _userManager.AddToRoleAsync(user, model.Role);

        await _activityLogger.LogAsync(
            "Creación de usuario",
            $"Se creó el usuario {user.Email} con rol {model.Role}."
        );

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> ToggleStatus(string id)
    {
        var user = await _userManager.FindByIdAsync(id);

        if (user == null)
            return NotFound();

        user.IsActive = !user.IsActive;
        await _userManager.UpdateAsync(user);

        await _activityLogger.LogAsync(
            "Cambio de estado de usuario",
            $"Se cambió el estado del usuario {user.Email} a {(user.IsActive ? "Activo" : "Inactivo")}."
        );

        return RedirectToAction(nameof(Index));
    }
}