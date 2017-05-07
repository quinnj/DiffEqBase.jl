type MonteCarloTestSolution{T,N,S} <: AbstractMonteCarloSolution{T,N}
  u::S
  errors::Dict{Symbol,Vector{T}}
  error_means::Dict{Symbol,T}
  error_medians::Dict{Symbol,T}
  elapsedTime::Float64
end
function MonteCarloTestSolution{T,N}(sim::AbstractMonteCarloSolution{T,N},errors,error_means,error_medians)
  MonteCarloTestSolution{T,N,typeof(sim.u)}(sim.u,errors,error_means,error_medians,sim.elapsedTime)
end

type MonteCarloSolution{T,N,S} <: AbstractMonteCarloSolution{T,N}
  u::S
  elapsedTime::Float64
end
MonteCarloSolution{N}(sim, dims::NTuple{N},elapsedTime) =
                  MonteCarloSolution{eltype(eltype(sim)), N, typeof(sim)}(sim,elapsedTime)
MonteCarloSolution(sim,elapsedTime) =
             MonteCarloSolution(sim, (size(sim[1])..., length(sim)),elapsedTime)

type MonteCarloSummary{T,N,Tt,S,S2} <: AbstractMonteCarloSolution{T,N}
  t::Tt
  u::S
  v::S2
  elapsedTime::Float64
end

function calculate_monte_errors(sim::AbstractMonteCarloSolution)
  u = sim.u
  errors = Dict{Symbol,Vector{eltype(u[1].u[1])}}() #Should add type information
  error_means  = Dict{Symbol,eltype(u[1].u[1])}()
  error_medians= Dict{Symbol,eltype(u[1].u[1])}()
  for k in keys(u[1].errors)
    errors[k] = [sol.errors[k] for sol in u]
    error_means[k] = mean(errors[k])
    error_medians[k]=median(errors[k])
  end
  return MonteCarloTestSolution(sim,errors,error_means,error_medians)
end

@recipe function f(sim::AbstractMonteCarloSolution;idxs=eachindex(sim.u[1]))
  for i in idxs
    @series begin
      legend := false
      sol[i]
    end
  end
end

@recipe function f(sim::MonteCarloSummary;idxs=eachindex(sim.u[1]))
  ci = vecarr_to_vectors(VectorOfArray([sim.v[i].*1.96 for i in 1:length(sim.v)]))
  u = vecarr_to_vectors(sim.u)
  for i in idxs
    @series begin
      legend := false
      alpha --> 0.4
      ribbon --> ci[i]
      sim.t,u[i]
    end
  end
end
