addprocs(int(CPU_CORES/2)-1)

using ParallelValueIteration
using GridWorld_
using Base.Test


function gridWorldTest(nProcs::Int, gridSize::Int, 
                       rPos::Array, rVals::Array, file::String;
                       nIter::Int=100, nChunks::Int=1)

    qt = readdlm(file)

    mdp = GridWorldMDP(gridSize, gridSize, rPos, rVals)

    nStates  = numStates(mdp)
    nActions = numActions(mdp)

    order = Array(Vector{Int}, nChunks)
    stride = int(nStates/nChunks)
    for i = 0:(nChunks-1)
        sIdx = i * stride + 1
        eIdx = sIdx + stride - 1
        if i == (nChunks-1) && eIdx != nStates
            eIdx = nStates
        end
        order[i+1] = [sIdx, eIdx] 

    end

    tolerance = 1e-10

    # test gauss-siedel
    gauss_siedel_flag = true
    pvi = ParallelSolver(nProcs, order, nIter, tolerance, gauss_siedel_flag)
    (utilp, qp) = solve(pvi, mdp)

    @test_approx_eq_eps qt qp 1.0


    # test regualr
    gauss_siedel_flag = false
    pvi = ParallelSolver(nProcs, order, nIter, tolerance, gauss_siedel_flag)
    (utilp, qp) = solve(pvi, mdp)

    @test_approx_eq_eps qt qp 1.0

    return true
end


rPos     = Array{Int64,1}[[8,9], [3,8], [5,4], [8,4]]
rVals    = [10.0, 3.0, -5.0, -10.0]
nProcs   = int(CPU_CORES/2) - 1
file     = "grid-world-10x10-Q-matrix.txt"
gridSize = 10

@test gridWorldTest(nProcs, gridSize, rPos, rVals, file) == true
@test gridWorldTest(nProcs, gridSize, rPos, rVals, file, nChunks=2) == true