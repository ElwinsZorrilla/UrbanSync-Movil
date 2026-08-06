using System.Security.Claims;
using UrbanSync.Web.Data;
using UrbanSync.Web.Models;

namespace UrbanSync.Web.Services;

public class ActivityLogger
{
    private readonly ApplicationDbContext _context;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ActivityLogger(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor)
    {
        _context = context;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<UserActivity?> LogAsync(
        string action,
        string description,
        string? entity = null,
        int? entityId = null)
    {
        var httpContext = _httpContextAccessor.HttpContext;

        var userId = httpContext?.User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(userId))
            return null;

        var ip = httpContext?.Connection.RemoteIpAddress?.ToString() ?? "Unknown";

        var activity = new UserActivity
        {
            UserId = userId,
            Action = action,
            Description = description,
            Entity = entity,
            EntityId = entityId,
            IpAddress = ip,
            CreatedAt = DateTime.UtcNow
        };

        _context.UserActivities.Add(activity);
        await _context.SaveChangesAsync();

        return activity;
    }
}