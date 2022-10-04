using Dapr.Client;
using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Hosting;
using System.Text.Json;
using TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks.Models;

namespace TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks
{
    public class EditModel : PageModel
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly DaprClient _daprClient;
        private TelemetryClient _telemetryClient;

        [BindProperty]
        public TaskUpdateModel? TaskUpdate { get; set; }

        public EditModel(IHttpClientFactory httpClientFactory, DaprClient daprClient, TelemetryClient telemetryClient)
        {
            _httpClientFactory = httpClientFactory;
            _daprClient = daprClient;
            _telemetryClient = telemetryClient;
        }

        public async Task<IActionResult> OnGetAsync(Guid? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            // direct svc to svc http request
            // var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");
            // var Task = await httpClient.GetFromJsonAsync<TaskModel>($"api/tasks/{id}");

            //Dapr SideCar Invocation
            var Task = await _daprClient.InvokeMethodAsync<TaskModel>(HttpMethod.Get, "tasksmanager-backend-api", $"api/tasks/{id}");

            if (Task == null)
            {
                return NotFound();
            }

            TaskUpdate = new TaskUpdateModel()
            {
                TaskId = Task.TaskId,
                TaskName = Task.TaskName,
                TaskAssignedTo = Task.TaskAssignedTo,
                TaskDueDate = Task.TaskDueDate,
            };

            return Page();
        }


        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            if (TaskUpdate != null)
            {
                // direct svc to svc http request
                // var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");
                // var result = await httpClient.PutAsJsonAsync($"api/tasks/{TaskUpdate.TaskId}", TaskUpdate);

                //Dapr SideCar Invocation
                await _daprClient.InvokeMethodAsync<TaskUpdateModel>(HttpMethod.Put, "tasksmanager-backend-api", $"api/tasks/{TaskUpdate.TaskId}", TaskUpdate);

            }

            return RedirectToPage("./Index");
        }

        public IActionResult OnGetDownloadFile(string fileNameWithoutExtension)
        {

            byte[] bytes;
            var fileName = Path.ChangeExtension(fileNameWithoutExtension, ".json");

            var directory = Path.Combine(Directory.GetCurrentDirectory(), "attachments");

            var filePath = Path.Combine(directory, fileName);

            try
            {
                //Read the File data into Byte Array.
                bytes = System.IO.File.ReadAllBytes(filePath);

                _telemetryClient.TrackEvent("DownloadRawTaskFromEdit");

                //Send the File to Download.
                return File(bytes, "application/octet-stream", fileName);
            }
            catch (FileNotFoundException)
            {
                var result = new NotFoundObjectResult(new { message = "File Not Found" });
                return result;
            }

        }
    }
}
