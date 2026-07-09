using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UrbanSync.Web.Data;

namespace UrbanSync.Web.Controllers;

[Authorize(Roles = "Administrador,Supervisor")]
public class ActivityController : Controller
{
    private readonly ApplicationDbContext _context;

    public ActivityController(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var activities = await _context.UserActivities
            .Include(x => x.User)
            .OrderByDescending(x => x.CreatedAt)
            .Take(100)
            .ToListAsync();

        return View(activities);
    }
}