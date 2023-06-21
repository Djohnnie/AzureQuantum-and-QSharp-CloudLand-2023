namespace solution
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation Superposition() : Unit 
    {
        // Allocate a single qubit
        use q = Qubit();
        
        // Keep count of the number of times the qubit is measured in the |1⟩ state
        mutable count = 0;

        // Loop 10.000 times
        for i in 1 .. 10000
        {
            // Put the qubit in the |+⟩ state
            H(q);

            // Measure the qubit and add 1 to the count if the qubit measures to |1⟩
            set count += MResetZ(q) == One ? 1 | 0;
        }

        // Output the number of times the qubit was measured in the |1⟩ state
        Message($"Number of times qubit was measured in the |1⟩ state: {count}.");
    }
}