using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;
using System.Reflection;

namespace TasksTracker.WebPortal.Frontend.Ui
{
    public class AppInsightsTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            if (string.IsNullOrEmpty(telemetry.Context.Cloud.RoleName))
            {
                var assembly = Assembly.GetExecutingAssembly();
                var informationVersion = assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion;
                //set custom role name here
                telemetry.Context.Cloud.RoleName = "tasksmanager-frontend-webapp";
                telemetry.Context.Component.Version = informationVersion;
            }
        }
    }
}
