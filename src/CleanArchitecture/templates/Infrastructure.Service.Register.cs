using DotnetCap;
using EfCore.IRepositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Sample.Domain.Constants;
using Sample.Infrastructure.Persistence.EfCore;
using Sample.Infrastructure.Repositories;

namespace Sample.Infrastructure
{
    public static partial class Register
    {
        public static IServiceCollection AddInfrastructureServices(
            this IServiceCollection services,
            IConfiguration configuration
        )
        {
            // Register DbContext
            // services.AddDbContext<ApplicationDbContext>(options =>
            //     options.UseSqlite(configuration.GetConnectionString("DefaultConnection")));

            //services.AddDotnetCap(configuration).AddRabbitMq(configuration);

            services.AddKeyedScoped<typeof(ICommandRepository), typeof(CommandDefaultRepository)>(
                ServiceKeys.CommandRepository,
            );
            services.TryAddKeyedScoped(
                typeof(IQueryRepository<,>),
                ServiceKeys.QueryRepository,
                typeof(QueryDefaultRepository<,>)
            );

            return services;
        }
    }
}
