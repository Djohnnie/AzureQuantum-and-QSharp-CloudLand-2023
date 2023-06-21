namespace solution
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation RandomByte() : Unit 
    {
        // Allocate 8 qubits to represent an 8-bit number (or byte)
        use qs = Qubit[8];

        // Put all the qubit into a superposition of 0 and 1
        ApplyToEach(H, qs);

        // Measure all qubit in the computational basis and
        // return the result as an array of results.
        let results = MeasureEachZ(qs);

        // Convert the array of binary results into an integer
        // which is a byte because we have 8 results
        let number = ResultArrayAsInt(results);

        // Output the resulting byte
        Message($"Random byte: {number}");
    }
}