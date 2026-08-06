using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanSync.Web.Migrations
{
    /// <inheritdoc />
    public partial class AddActivityEntityColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Entity",
                table: "UserActivities",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "EntityId",
                table: "UserActivities",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserActivities_CreatedAt",
                table: "UserActivities",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_UserActivities_Entity_EntityId",
                table: "UserActivities",
                columns: new[] { "Entity", "EntityId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserActivities_CreatedAt",
                table: "UserActivities");

            migrationBuilder.DropIndex(
                name: "IX_UserActivities_Entity_EntityId",
                table: "UserActivities");

            migrationBuilder.DropColumn(
                name: "Entity",
                table: "UserActivities");

            migrationBuilder.DropColumn(
                name: "EntityId",
                table: "UserActivities");
        }
    }
}
