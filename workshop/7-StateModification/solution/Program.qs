namespace solution
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation StateModification() : Unit 
    {
        // Allocate a single qubit
        use q = Qubit();

        // Flip the qubit from |0⟩ to |1⟩
        H(q);
        Z(q);
        H(q);

        // Measure the qubit in the computational basis
        let bit = MResetZ(q) == One ? 1 | 0;

        // Output a calculated probability based
        // on the count and number of samples
        Message($"Result: {bit}");        
    }
}