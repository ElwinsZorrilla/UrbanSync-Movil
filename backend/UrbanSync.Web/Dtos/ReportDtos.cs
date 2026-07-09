namespace UrbanSync.Web.Dtos;

public class CountItem
{
    public string Clave { get; set; } = string.Empty;
    public int Total { get; set; }
}

public class ReportSummaryDto
{
    public int Total { get; set; }
    public List<CountItem> PorEstado { get; set; } = new();
    public List<CountItem> PorTipo { get; set; } = new();
    public List<CountItem> PorPrioridad { get; set; } = new();
    public List<CountItem> PorJurisdiccion { get; set; } = new();
}
