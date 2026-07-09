FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY UrbanSync.Web/UrbanSync.Web.csproj UrbanSync.Web/
RUN dotnet restore UrbanSync.Web/UrbanSync.Web.csproj

COPY . .
RUN dotnet publish UrbanSync.Web/UrbanSync.Web.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "UrbanSync.Web.dll"]
