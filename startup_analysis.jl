using GenX
using CSV
using DataFrames
using Plots
using Statistics

case_path = joinpath(@__DIR__, "genx_case")

# Startup configuration
startup_config = Dict(
    "type" => "green_ammonia",
    "energy_requirement_MW" => 10,
    "capital_cost_$" => 5000000,
    "required_energy_price_$_per_MWh" => 50,
    "location" => "California"
)

"""
Run a GenX case for the specified path.
"""
function run_genx_case(case_path::String)
    try
        run_genx_case!(case_path)
        println("GenX case completed successfully for: $case_path")
    catch e
        println("Error running GenX case: $e")
        rethrow(e)
    end
end

"""
Process GenX outputs and return key results.
"""
function process_genx_outputs(case_path::String)
    results_path = joinpath(case_path, "Results")
    
    capacity_df = CSV.read(joinpath(results_path, "capacity.csv"), DataFrame)
    cost_df = CSV.read(joinpath(results_path, "costs.csv"), DataFrame)
    power_df = CSV.read(joinpath(results_path, "power.csv"), DataFrame)
    
    total_capacity = sum(capacity_df.EndCap)
    avg_price = mean(power_df[:, r"Price_\$_per_MWh"])
    total_cost = sum(cost_df.AnnualizedCost)
    
    return Dict(
        "total_capacity_MW" => total_capacity,
        "avg_electricity_price_$_per_MWh" => avg_price,
        "total_cost_$" => total_cost
    )
end

"""
Assess startup viability based on GenX results.
"""
function assess_viability(startup_config::Dict, genx_results::Dict)
    required_price = startup_config["required_energy_price_$_per_MWh"]
    actual_price = genx_results["avg_electricity_price_$_per_MWh"]
    
    if actual_price <= required_price
        return "Viable"
    elseif actual_price <= required_price * 1.2
        return "Marginally Viable"
    else
        return "Not Viable"
    end
end

"""
Visualize key GenX results.
"""
function visualize_results(genx_results::Dict)
    p = bar(["Total Capacity (MW)", "Avg Price (\$/MWh)", "Total Cost (\$)"],
            [genx_results["total_capacity_MW"],
             genx_results["avg_electricity_price_$_per_MWh"],
             genx_results["total_cost_$"] / 1e6],  # Convert to millions for better visualization
            title="GenX Results Summary",
            ylabel="Value",
            legend=false)
    savefig(p, "genx_results_summary.png")
    println("Results visualization saved as genx_results_summary.png")
end

"""
Main function to run the analysis.
"""
function main()
    println("Analyzing startup: $(startup_config["type"])")
    
    # Assuming you have a GenX case set up for the startup's location
    case_path = joinpath(@__DIR__, "genx_case")
    
    run_genx_case(case_path)
    genx_results = process_genx_outputs(case_path)
    viability = assess_viability(startup_config, genx_results)
    
    println("\nGenX Results:")
    for (key, value) in genx_results
        println("$key: $value")
    end
    
    println("\nStartup Viability: $viability")
    
    visualize_results(genx_results)
    
    # Save results
    open("startup_analysis.txt", "w") do io
        println(io, "Startup Type: $(startup_config["type"])")
        println(io, "Location: $(startup_config["location"])")
        println(io, "Energy Requirement: $(startup_config["energy_requirement_MW"]) MW")
        println(io, "Required Energy Price: \$$(startup_config["required_energy_price_$_per_MWh"]) per MWh")
        println(io, "\nGenX Results:")
        for (key, value) in genx_results
            println(io, "$key: $value")
        end
        println(io, "\nViability Assessment: $viability")
    end
    
    println("\nAnalysis complete. Results saved to startup_analysis.txt")
end

# Run the main function
main()