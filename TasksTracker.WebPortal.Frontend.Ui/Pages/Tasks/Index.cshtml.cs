using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks.Models;

namespace TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks
{
    public class IndexModel : PageModel
    {

        private readonly IHttpClientFactory _httpClientFactory;
        public List<TaskModel>? TasksList { get; set; }

        [BindProperty]
        public string? TasksCreatedBy { get; set; }

        public IndexModel(IHttpClientFactory httpClientFactory)
        {
            _httpClientFactory = httpClientFactory;
        }

        public async Task OnGetAsync()
        {
           
            TasksCreatedBy = Request.Cookies["TasksCreatedByCookie"];
            
            //Invoke via internal URL (Not Dapr)
            //var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");
            //TasksList = await httpClient.GetFromJsonAsync<List<TaskModel>>($"api/tasks?createdBy={TasksCreatedBy}");


            // Invoke via Dapr SideCar URL
            //var port = 3500;//Environment.GetEnvironmentVariable("DAPR_HTTP_PORT");
            //HttpClient client = new HttpClient();
            //var result = await client.GetFromJsonAsync<List<TaskModel>>($"http://localhost:{port}/v1.0/invoke/tasksmanager-backend-api/method/api/tasks?createdBy={TasksCreatedBy}");
            //TasksList = result;

            // Invoke via DaprSDK
            var daprCLient = new Dapr.Client.DaprClientBuilder().Build();
            var result = await daprCLient.InvokeMethodAsync<List<TaskModel>>(HttpMethod.Get, "tasksmanager-backend-api", $"api/tasks?createdBy={TasksCreatedBy}");
            TasksList = result;

        }

        public async Task<IActionResult> OnPostDeleteAsync(Guid id)
        {
            var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");

            var result = await httpClient.DeleteAsync($"api/tasks/{id}");

            return RedirectToPage();          
        }

        public async Task<IActionResult> OnPostCompleteAsync(Guid id)
        {
            var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");

            var result = await httpClient.PutAsync($"api/tasks/{id}/markcomplete", null);

            return RedirectToPage();
        }
    }
}
