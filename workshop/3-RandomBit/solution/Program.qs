namespace solution
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation RandomBit() : Unit 
    {
        // Allocate a single qubit
        use q = Qubit();

        // Put the qubit into a superposition of 0 and 1
        H(q);

        // Measure the qubit in the computational basis and return
        // the result as an array containing a single element
        let results = MeasureEachZ([q]);

        // Convert the array of binary results into an integer
        // which is a bit because we only have a single result
        let bit = ResultArrayAsInt(results);

        // Output the resulting bit
        Message($"Random bit: {bit}");
    }
}