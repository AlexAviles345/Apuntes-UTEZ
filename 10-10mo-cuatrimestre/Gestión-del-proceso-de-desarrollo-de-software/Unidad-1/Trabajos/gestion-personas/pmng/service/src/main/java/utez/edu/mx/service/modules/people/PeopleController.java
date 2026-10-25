package utez.edu.mx.service.modules.people;

import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import utez.edu.mx.service.kernel.ApiResponse;

@RestController
@RequestMapping("/people")
@CrossOrigin(origins = "*")
@AllArgsConstructor
public class PeopleController {
    private final PeopleService peopleService;

    @GetMapping("")
    public ResponseEntity<ApiResponse> findAll() {
        return peopleService.findAll();
    }

    @PostMapping("")
    public ResponseEntity<ApiResponse> savePerson(@RequestBody Person payload) {
        return peopleService.savePerson(payload);
    }
}
