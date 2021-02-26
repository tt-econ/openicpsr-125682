OVERVIEW
==========================================================
This library contains code for estimating and simulating maximum likelihood models.

The library is designed to make it easy to implement arbitrary likelihood models, including models that require numerical integration to compute the likelihood. The main classes in the library are:

- MleModel: An abstract class that provides a template for maximum likelihood models and defines key methods such as Estimate() and Simulate().

- MleData: A class that defines dataset objects.

- MleEstimationOutput: A class that defines the output of the estimation routine.

To implement a model, the user defines a subclass of the abstract class MleModel. A valid implementation must specifiy the model's parameters, unobservables (stochastic variables that will be integrated numerically) and errors (stochastic variables that will not be integrated numerically). It must also implement three functions, one that returns the likelihood of each observation in a dataset given parameters and unobservables, a second that returns a vector of outcomes given parameters, errors, and unobservables, and a third that computes the model's unobservables given a vector of i.i.d. draws.

The library includes two implementations of MleModel: LinearRegressionModel() and BinaryLogitModel(). Both of these can be used as "off-the-shelf" estimation tools. They can also serve as examples to guide users in implementing their own models.

The /test/ directory also includes a "toy" implementation of MleModel, ExampleModel(), which implements an estimator for the mean and variance of a univariate normal outcome.

To get a quick look at how to use the library, browse /test/test_example_model.m. For more detailed documentation, open Matlab, make sure /gslab_mle/m/ is on the path, and type "doc MleModel" followed by "doc MleData" and "doc MleEstimationOutput."

NOTES ON IMPLEMENTATION
==========================================================
- Methods of MleModel (e.g., computing the sum of log likelihoods) are vectorized. Therefore, to exploit parallel computing, the user should parallelize loops inside the user-defined method ComputeConditionalLikelihoodVector.

REFERENCES
==========================================================
- Maximization problems are solved using KNITRO (http://www.ziena.com/knitro.htm).
- Numerical integration is performed using Sparse Grid Integration (http://sparse-grids.de/).
