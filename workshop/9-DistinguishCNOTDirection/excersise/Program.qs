namespace excersise
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
        // TODO: Check the direction of the CNOT operation
        // and use the Message function to output the result.
    }
}