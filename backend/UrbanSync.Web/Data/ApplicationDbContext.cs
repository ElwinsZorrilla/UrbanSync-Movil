using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using UrbanSync.Web.Domain;
using UrbanSync.Web.Models;

namespace UrbanSync.Web.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<UserActivity> UserActivities => Set<UserActivity>();

    public DbSet<Jurisdiccion> Jurisdicciones => Set<Jurisdiccion>();
    public DbSet<Institucion> Instituciones => Set<Institucion>();
    public DbSet<TipoIncidencia> TiposIncidencia => Set<TipoIncidencia>();
    public DbSet<Ubicacion> Ubicaciones => Set<Ubicacion>();
    public DbSet<Incidencia> Incidencias => Set<Incidencia>();
    public DbSet<Evidencia> Evidencias => Set<Evidencia>();
    public DbSet<AnalisisTecnico> AnalisisTecnicos => Set<AnalisisTecnico>();
    public DbSet<Trabajo> Trabajos => Set<Trabajo>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Jurisdiccion>()
            .HasOne(j => j.JurisdiccionPadre)
            .WithMany()
            .HasForeignKey(j => j.JurisdiccionPadreId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<TipoIncidencia>()
            .HasOne(t => t.Institucion)
            .WithMany()
            .HasForeignKey(t => t.InstitucionId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Ubicacion>(entity =>
        {
            entity.Property(u => u.Latitud).HasPrecision(10, 7);
            entity.Property(u => u.Longitud).HasPrecision(10, 7);
            entity.HasOne(u => u.Jurisdiccion)
                .WithMany()
                .HasForeignKey(u => u.JurisdiccionId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Incidencia>(entity =>
        {
            entity.HasIndex(i => i.CodigoCaso).IsUnique();

            entity.HasOne(i => i.UsuarioReporta)
                .WithMany()
                .HasForeignKey(i => i.UsuarioReportaId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(i => i.TipoIncidencia)
                .WithMany()
                .HasForeignKey(i => i.TipoIncidenciaId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(i => i.Ubicacion)
                .WithMany()
                .HasForeignKey(i => i.UbicacionId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(i => i.InstitucionAsignada)
                .WithMany()
                .HasForeignKey(i => i.InstitucionAsignadaId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Evidencia>(entity =>
        {
            entity.Property(e => e.Latitud).HasPrecision(10, 7);
            entity.Property(e => e.Longitud).HasPrecision(10, 7);

            entity.HasOne(e => e.Incidencia)
                .WithMany(i => i.Evidencias)
                .HasForeignKey(e => e.IncidenciaId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.UsuarioSube)
                .WithMany()
                .HasForeignKey(e => e.UsuarioSubeId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<AnalisisTecnico>(entity =>
        {
            entity.HasOne(a => a.Incidencia)
                .WithMany()
                .HasForeignKey(a => a.IncidenciaId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(a => a.UsuarioTecnico)
                .WithMany()
                .HasForeignKey(a => a.UsuarioTecnicoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Trabajo>(entity =>
        {
            entity.HasOne(t => t.Incidencia)
                .WithMany(i => i.Trabajos)
                .HasForeignKey(t => t.IncidenciaId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(t => t.UsuarioAsignado)
                .WithMany()
                .HasForeignKey(t => t.UsuarioAsignadoId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
