namespace solution
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation DistinguishHX() : Unit 
    {
        // Run the H operation
        Solve(H);
        
        // Run the X operation
        Solve(X);
    }

    operation Solve( op: (Qubit => Unit)) : Unit
    {
        // Allocate a qubit
        use q = Qubit();

        // Apply the 'unknown' operation
        op(q);

        // Apply the Z rotation
        Z(q);

        // Apply the 'unknown' operation again
        op(q);

        // Measure the qubit
        if( MResetZ(q) == One )
        {
            // If the operation was H, the qubit would go from:
            // - The |0⟩ state to the |+⟩ state
            // - The |+⟩ state to the |-⟩ state
            // - The |-⟩ state to the |1⟩ state
            Message("H");
        }
        else
        {
            // If the operation was X, the qubit would go from:
            // - The |0⟩ state to the |1⟩ state
            // - The |1⟩ state to the |1⟩ state
            // - The |1⟩ state to the |0⟩ state
            Message("X");
        }
    }
}