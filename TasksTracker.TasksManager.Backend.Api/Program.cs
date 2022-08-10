using Dapr.Client;
using TasksTracker.TasksManager.Backend.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddSingleton<DaprClient>(_ => new DaprClientBuilder().Build());

//builder.Services.AddSingleton<ITasksManager, FakeTasksManager>();

builder.Services.AddSingleton<ITasksManager, TasksStoreManager>();

builder.Services.AddControllers();

var app = builder.Build();

// Configure the HTTP request pipeline.

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
