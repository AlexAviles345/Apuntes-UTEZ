package mx.edu.utez.backend.test;

import mx.edu.utez.backend.kernel.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

@RestController
@RequestMapping("/test")
@CrossOrigin(origins = "*")
public class TestController {

    private final TestService testService;

    private TestController(TestService testService){
        this.testService = testService;
    }

    @GetMapping("")
    public ResponseEntity<ApiResponse> consultarOtroBackend(){
        ApiResponse response = testService.consultarOtroBackend();

        return new ResponseEntity<>(response, response.getStatus());
    }

    @GetMapping("/retrieve")
    public ResponseEntity<ApiResponse> responderLlamada(){
        ApiResponse response = testService.responderLlamada();

        return new ResponseEntity<>(response, response.getStatus());
    }
}
