using Microsoft.AspNetCore.Identity;

namespace UrbanSync.Web.Models;

public class ApplicationUser : IdentityUser
{
    public string FullName { get; set; } = string.Empty;

    public string IdentificationNumber { get; set; } = string.Empty;

    public string Position { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}