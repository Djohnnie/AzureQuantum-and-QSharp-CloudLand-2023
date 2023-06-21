namespace excersise
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation Entanglement() : Unit 
    {
        // TODO: Modify the following code fragment that outputs |00⟩ and |11⟩
        // with equal probability to output |10⟩ and |01⟩ with equal probability.

        // Allocate two qubits for entanglement
        use (q1, q2) = (Qubit(), Qubit());
        
        // Loop 10 times
        for i in 1 .. 10
        {
            // Entangle the two qubits
            H(q1);
            CNOT(q1, q2);

            // Measure the qubits and output the result
            let results = MeasureEachZ([q1, q2]);
            Message($"|{results[0] == One ? 1 | 0}{results[1] == One ? 1 | 0}⟩");

            ResetAll([q1, q2]);
        }
    }
}