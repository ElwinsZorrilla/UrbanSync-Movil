using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using UrbanSync.Web.Domain;
using UrbanSync.Web.Models;

namespace UrbanSync.Web.Data;

public static class SeedData
{
    public static async Task InitializeAsync(IServiceProvider serviceProvider)
    {
        var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var context = serviceProvider.GetRequiredService<ApplicationDbContext>();

        string[] roles =
        {
            "Administrador",
            "Supervisor",
            "Tecnico",
            "Ciudadano"
        };

        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }

        await CreateUserAsync(
            userManager,
            "admin@urbansync.com",
            "Admin123*",
            "Administrador UrbanSync",
            "00000000000",
            "Administrador General",
            "Administrador"
        );

        await CreateUserAsync(
            userManager,
            "supervisor@urbansync.com",
            "Supervisor123*",
            "Supervisor Municipal",
            "00100000001",
            "Supervisor de Operaciones",
            "Supervisor"
        );

        await CreateUserAsync(
            userManager,
            "tecnico@urbansync.com",
            "Tecnico123*",
            "Técnico de Infraestructura",
            "00100000002",
            "Técnico de Reparaciones",
            "Tecnico"
        );

        await CreateUserAsync(
            userManager,
            "ciudadano@urbansync.com",
            "Ciudadano123*",
            "Ciudadano de Prueba",
            "00100000003",
            "Ciudadano",
            "Ciudadano"
        );

        await SeedDomainAsync(context);
    }

    private static async Task SeedDomainAsync(ApplicationDbContext context)
    {
        var electricidad = await EnsureInstitucionAsync(context, "Empresa Distribuidora de Electricidad", "Electricidad", "contacto@edeeste.example");
        var mopc = await EnsureInstitucionAsync(context, "Ministerio de Obras Publicas y Comunicaciones (MOPC)", "Infraestructura", "contacto@mopc.example");
        var general = await EnsureInstitucionAsync(context, "Institucion General de Servicios", "Otro", "contacto@general.example");

        await EnsureTipoAsync(context, "Problema Electrico", "Fallas o incidencias relacionadas al servicio electrico", electricidad.Id);
        await EnsureTipoAsync(context, "Infraestructura Fisica", "Danos en vias, aceras, edificaciones publicas", mopc.Id);
        await EnsureTipoAsync(context, "Otro", "Incidencias que no encajan en una categoria especifica", general.Id);

        if (!await context.Jurisdicciones.AnyAsync(j => j.Nombre == "Distrito Nacional"))
        {
            context.Jurisdicciones.Add(new Jurisdiccion { Nombre = "Distrito Nacional", Nivel = "Provincia" });
            await context.SaveChangesAsync();
        }
    }

    private static async Task<Institucion> EnsureInstitucionAsync(
        ApplicationDbContext context, string nombre, string tipo, string email)
    {
        var institucion = await context.Instituciones.FirstOrDefaultAsync(i => i.Nombre == nombre);

        if (institucion == null)
        {
            institucion = new Institucion { Nombre = nombre, TipoInstitucion = tipo, ContactoEmail = email };
            context.Instituciones.Add(institucion);
            await context.SaveChangesAsync();
        }

        return institucion;
    }

    private static async Task EnsureTipoAsync(
        ApplicationDbContext context, string nombre, string descripcion, int institucionId)
    {
        if (!await context.TiposIncidencia.AnyAsync(t => t.Nombre == nombre))
        {
            context.TiposIncidencia.Add(new TipoIncidencia
            {
                Nombre = nombre,
                Descripcion = descripcion,
                InstitucionId = institucionId
            });
            await context.SaveChangesAsync();
        }
    }

    private static async Task CreateUserAsync(
        UserManager<ApplicationUser> userManager,
        string email,
        string password,
        string fullName,
        string identificationNumber,
        string position,
        string role)
    {
        var user = await userManager.FindByEmailAsync(email);

        if (user != null)
            return;

        user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            FullName = fullName,
            IdentificationNumber = identificationNumber,
            Position = position,
            EmailConfirmed = true,
            IsActive = true
        };

        var result = await userManager.CreateAsync(user, password);

        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(user, role);
        }
    }
}