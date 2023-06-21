namespace solution
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation DistinguishCNOTDirection() : Unit 
    {
        // Run the CNOT operation for CNOT12
        Solve((q1, q2) => CNOT(q1, q2));
        
        // Run the CNOT operation for CNOT21
        Solve((q1, q2) => CNOT(q2, q1));
    }

    operation Solve( op: ((Qubit, Qubit) => Unit)) : Unit
    {
        // Allocate two qubits |00⟩ to test the direction of CNOT
        use (q1, q2) = (Qubit(), Qubit());

        // Flip the second qubit to get |01⟩
        X(q2);

        // Apply the 'unknown' operation
        op(q1, q2);

        // If the first qubit remains zero, then CNOT12 is applied.
        if( M(q1) == Zero )
        {
            // CNOT12 |01⟩ = |01⟩
            Message("CNOT12");
        }
        else
        {
            // CNOT21 |01⟩ = |11⟩
            Message("CNOT21");
        }

        Reset(q1);
        Reset(q2);
    }
}