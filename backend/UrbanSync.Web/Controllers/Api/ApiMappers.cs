using UrbanSync.Web.Domain;
using UrbanSync.Web.Dtos;

namespace UrbanSync.Web.Controllers.Api;

public static class ApiMappers
{
    public static string BuildPublicUrl(HttpRequest request, string ruta)
    {
        if (string.IsNullOrEmpty(ruta))
            return string.Empty;

        if (ruta.StartsWith("http", StringComparison.OrdinalIgnoreCase))
            return ruta;

        var baseUrl = $"{request.Scheme}://{request.Host}";
        return ruta.StartsWith('/') ? baseUrl + ruta : $"{baseUrl}/{ruta}";
    }

    public static EvidenceDto MapEvidence(Evidencia e, HttpRequest request) => new()
    {
        Id = e.Id,
        TipoEvidencia = e.TipoEvidencia,
        Url = BuildPublicUrl(request, e.RutaArchivo),
        Descripcion = e.Descripcion,
        Latitud = (double?)e.Latitud,
        Longitud = (double?)e.Longitud,
        FechaSubida = e.FechaSubida,
        UsuarioSube = e.UsuarioSube?.FullName ?? string.Empty
    };

    public static IncidentDto MapIncident(Incidencia i, HttpRequest request, bool includeEvidencias)
    {
        var dto = new IncidentDto
        {
            Id = i.Id,
            CodigoCaso = i.CodigoCaso,
            Estado = i.Estado,
            Prioridad = i.Prioridad,
            Descripcion = i.Descripcion,
            TipoIncidenciaId = i.TipoIncidenciaId,
            TipoIncidencia = i.TipoIncidencia?.Nombre ?? string.Empty,
            InstitucionAsignadaId = i.InstitucionAsignadaId,
            InstitucionAsignada = i.InstitucionAsignada?.Nombre,
            JurisdiccionId = i.Ubicacion?.JurisdiccionId ?? 0,
            Jurisdiccion = i.Ubicacion?.Jurisdiccion?.Nombre ?? string.Empty,
            Direccion = i.Ubicacion?.Direccion ?? string.Empty,
            Referencia = i.Ubicacion?.Referencia,
            Latitud = (double?)i.Ubicacion?.Latitud,
            Longitud = (double?)i.Ubicacion?.Longitud,
            UsuarioReporta = i.UsuarioReporta?.FullName ?? string.Empty,
            FechaReporte = i.FechaReporte,
            FechaAsignacion = i.FechaAsignacion,
            FechaCierre = i.FechaCierre
        };

        if (includeEvidencias)
            dto.Evidencias = i.Evidencias.Select(e => MapEvidence(e, request)).ToList();

        return dto;
    }

    public static WorkOrderDto MapWorkOrder(Trabajo t) => new()
    {
        Id = t.Id,
        IncidenciaId = t.IncidenciaId,
        CodigoCaso = t.Incidencia?.CodigoCaso ?? string.Empty,
        UsuarioAsignadoId = t.UsuarioAsignadoId,
        UsuarioAsignado = t.UsuarioAsignado?.FullName ?? string.Empty,
        DescripcionTrabajo = t.DescripcionTrabajo,
        Estado = t.Estado,
        FechaInicio = t.FechaInicio,
        FechaFin = t.FechaFin,
        Resultado = t.Resultado
    };
}
