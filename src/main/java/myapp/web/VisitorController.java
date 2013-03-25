package myapp.web;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;


@Controller
public class VisitorController {

    private Logger logger = LoggerFactory.getLogger(VisitorController.class);

    @RequestMapping("/")
    public ModelAndView home(HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        return index(request, response);
    }

    @RequestMapping("/index")
    public ModelAndView index(HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        ModelAndView mv = new ModelAndView("index");
        return mv;
    }


}
