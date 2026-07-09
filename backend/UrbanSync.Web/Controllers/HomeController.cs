using Microsoft.AspNetCore.Mvc;

namespace UrbanSync.Web.Controllers;

public class HomeController : Controller
{
    public IActionResult AccessDenied()
    {
        return View();
    }
}