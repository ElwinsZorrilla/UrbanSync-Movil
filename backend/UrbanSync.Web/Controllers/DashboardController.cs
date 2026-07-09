using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace UrbanSync.Web.Controllers;

[Authorize]
public class DashboardController : Controller
{
    public IActionResult Index()
    {
        if (User.IsInRole("Administrador"))
            return View("Administrador");

        if (User.IsInRole("Supervisor"))
            return View("Supervisor");

        if (User.IsInRole("Tecnico"))
            return View("Tecnico");

        return View("Ciudadano");
    }
}