namespace exercise
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation StateModification() : Unit 
    {
        // TODO: Adjust the following code fragment to flip the qubit
        // without using the X operation.
        // TIP: You are only allowed to use the H and Z operations.

        // Allocate a single qubit
        use q = Qubit();

        // Flip the qubit from |0⟩ to |1⟩
        X(q);

        // Measure the qubit in the computational basis
        let bit = MResetZ(q) == One ? 1 | 0;

        // Output a calculated probability based
        // on the count and number of samples
        Message($"Result: {bit}");
    }
}